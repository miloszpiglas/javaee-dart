package pl.mpiglas.tree.endpoint.rest;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

import javax.annotation.Resource;
import javax.ejb.EJB;
import javax.naming.InitialContext;
import javax.naming.NamingException;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.persistence.TypedQuery;
import javax.transaction.NotSupportedException;
import javax.transaction.SystemException;
import javax.transaction.UserTransaction;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.Response.Status;

import org.jboss.arquillian.container.test.api.Deployment;
import org.jboss.arquillian.core.api.annotation.Inject;
import org.jboss.arquillian.junit.Arquillian;
import org.jboss.shrinkwrap.api.Archive;
import org.jboss.shrinkwrap.api.ShrinkWrap;
import org.jboss.shrinkwrap.api.asset.EmptyAsset;
import org.junit.After;
import org.junit.Assert;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.wildfly.swarm.undertow.WARArchive;

import pl.mpiglas.tree.ejb.core.TreeManager;
import pl.mpiglas.tree.model.entity.TreeNodeEntity;
import pl.mpiglas.tree.model.transfer.TreeNode;

/**
 * Integration tests for {@link TreeService}.
 * @author mpiglas
 *
 */
@RunWith(Arquillian.class)
public class TreeServiceIT {

	@Deployment
	public static Archive createDeployment() {
		WARArchive archive = ShrinkWrap.create(WARArchive.class).addClasses(
				TreeManager.class, TreeNode.class, TreeNodeEntity.class,
				TreeService.class);
		archive.addAsWebInfResource("persistence.xml",
				"classes/META-INF/persistence.xml");
		archive.addAsManifestResource(EmptyAsset.INSTANCE, "beans.xml");
		return archive;
	}

	@PersistenceContext
	EntityManager em;

	@Resource
	UserTransaction ut;

	private TreeService getService() throws NamingException {
		InitialContext context = new InitialContext();
		TreeService service = (TreeService) context
				.lookup("java:module/TreeService!pl.mpiglas.tree.endpoint.rest.TreeService");
		return service;
	}

	private Optional<TreeNode> getNode(long id) throws NamingException {

		return getService().getAll().stream()
				.filter(n -> n.getId().longValue() == id).findFirst();
	}

	@After
	public void cleanDb() {
		try {
			ut.begin();
			int rows = em.createQuery("DELETE FROM TreeNodeEntity e")
					.executeUpdate();
			System.out.println("Deleted rows " + rows);
			ut.commit();
		} catch (Exception e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}

	@Test
	public void shouldCreateRootNode() throws NamingException {
		System.out.println(em != null);

		TreeNode node = new TreeNode();
		node.setValue(100d);
		TreeNode root = (TreeNode) getService().create(node).getEntity();
		Assert.assertEquals(100d, root.getValue().doubleValue(), 0.0);
		Assert.assertNull(root.getParentId());

	}

	private TreeNode newNode(Long parentId, double value) {
		TreeNode tn = new TreeNode();
		tn.setParentId(parentId);
		tn.setValue(value);
		return tn;
	}

	@Test
	public void shouldAddNodeToRoot() throws NamingException {
		TreeService srv = getService();
		// given
		TreeNode root = (TreeNode) srv.create(newNode(null, 100)).getEntity();

		// when
		TreeNode child = (TreeNode) srv.create(newNode(root.getId(), 200))
				.getEntity();

		// then
		Assert.assertEquals(root.getId().longValue(), child.getParentId()
				.longValue());

	}

	@Test
	public void shouldNotAddNodeWithUnknownRoot() throws NamingException {
		TreeService srv = getService();
		// given
		TreeNode root = (TreeNode) srv.create(newNode(null, 100)).getEntity();

		// when
		Response child = srv.create(newNode(root.getId() + 50, 200));

		// then
		Assert.assertEquals(Status.BAD_REQUEST.getStatusCode(),
				child.getStatus());

	}

	@Test
	public void shouldNotAddSecondRoot() throws NamingException {
		TreeService srv = getService();
		// given
		TreeNode root = (TreeNode) srv.create(newNode(null, 400)).getEntity();

		// when
		Response child = srv.create(newNode(null, 500));

		// then
		Assert.assertEquals(Status.BAD_REQUEST.getStatusCode(),
				child.getStatus());
	}

	@Test
	public void shouldUpdateLeaf() throws NamingException {
		// given
		TreeService srv = getService();
		TreeNode root = (TreeNode) srv.create(newNode(null, 6000)).getEntity();
		TreeNode child = (TreeNode) srv.create(newNode(root.getId(), 7000))
				.getEntity();

		// when
		TreeNode un = newNode(root.getId(), 9000);
		un.setId(child.getId());
		Response updateResult = srv.update(un);
		Optional<TreeNode> childEntity = getNode(child.getId());

		// then
		Assert.assertEquals(Status.OK.getStatusCode(), updateResult.getStatus());
		Assert.assertEquals(child.getId().longValue(), childEntity.get()
				.getId().longValue());
		Assert.assertEquals(child.getParentId().longValue(), childEntity.get()
				.getParentId().longValue());
		Assert.assertEquals(9000d, childEntity.get().getValue().doubleValue(),
				0.0);

	}

	@Test
	public void shouldDeleteLeaf() throws NamingException {

		// given
		TreeService srv = getService();
		TreeNode root = (TreeNode) srv.create(newNode(null, 6000)).getEntity();
		TreeNode child = (TreeNode) srv.create(newNode(root.getId(), 7000))
				.getEntity();

		// when
		Response resp = srv.deleteId(child.getId().toString());

		// then
		Assert.assertEquals(Status.OK.getStatusCode(), resp.getStatus());
		List<TreeNode> allNodes = srv.getAll();
		Assert.assertEquals(1, allNodes.size());
	}

	@Test
	public void shouldDeleteBranch() throws NamingException {

		// given
		TreeService srv = getService();
		TreeNode root = (TreeNode) srv.create(newNode(null, 6000)).getEntity();
		TreeNode child = (TreeNode) srv.create(newNode(root.getId(), 7000))
				.getEntity();
		TreeNode ch2 = (TreeNode) srv.create(newNode(root.getId(), 8000))
				.getEntity();
		srv.create(newNode(ch2.getId(), 9000));

		// when
		Response resp = srv.deleteId(ch2.getId().toString());
		Optional<TreeNode> childEntity = getNode(child.getId());

		// then
		Assert.assertEquals(Status.OK.getStatusCode(), resp.getStatus());
		List<TreeNode> allNodes = srv.getAll();
		Assert.assertEquals(2, allNodes.size());
		Assert.assertEquals(child.getId().longValue(), childEntity.get()
				.getId().longValue());
		Assert.assertEquals(child.getParentId().longValue(), childEntity.get()
				.getParentId().longValue());
	}

	@Test
	public void shouldDeleteAll() throws NamingException {
		// given
		TreeService srv = getService();
		TreeNode root = (TreeNode) srv.create(newNode(null, 6000)).getEntity();
		srv.create(newNode(root.getId(), 7000)).getEntity();
		TreeNode ch2 = (TreeNode) srv.create(newNode(root.getId(), 8000))
				.getEntity();
		srv.create(newNode(ch2.getId(), 9000));

		// when
		Response resp = srv.deleteId(root.getId().toString());

		// then
		Assert.assertEquals(Status.OK.getStatusCode(), resp.getStatus());
		List<TreeNode> allNodes = srv.getAll();
		Assert.assertEquals(0, allNodes.size());
	}

	@Test
	public void shouldReturnBadRequestIfNodeIdIsInvalid()
			throws NamingException {
		// given
		TreeService srv = getService();

		// when
		Response resp = srv.deleteId("abc");

		// then
		Assert.assertEquals(Status.BAD_REQUEST.getStatusCode(),
				resp.getStatus());
	}

	@Test
	public void shouldReturnBadRequestIfNodeIdIsNotDefinedWhenUpdate() throws NamingException {
		// given
		TreeService srv = getService();
		TreeNode un = TreeNode.newNode(null, 100d);
		// when
		Response resp = srv.update(un);

		// then
		Assert.assertEquals(Status.BAD_REQUEST.getStatusCode(),
				resp.getStatus());
	}
	
	@Test
	public void shouldReturnBadRequestIfValueIsNotDefinedWhenUpdate() throws NamingException {
		// given
		TreeService srv = getService();
		TreeNode un = TreeNode.newNode(null, null);
		un.setId(1L);
		// when
		Response resp = srv.update(un);

		// then
		Assert.assertEquals(Status.BAD_REQUEST.getStatusCode(),
				resp.getStatus());
	}
	
	@Test
	public void shouldReturnBadRequestIfValueIsNotDefinedWhenCreate() throws NamingException {
		// given
		TreeService srv = getService();
		TreeNode un = TreeNode.newNode(null, null);
		un.setId(1L);
		// when
		Response resp = srv.create(un);

		// then
		Assert.assertEquals(Status.BAD_REQUEST.getStatusCode(),
				resp.getStatus());
	}

}
