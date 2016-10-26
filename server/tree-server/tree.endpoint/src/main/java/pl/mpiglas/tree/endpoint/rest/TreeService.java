package pl.mpiglas.tree.endpoint.rest;

import java.util.List;
import java.util.Optional;

import javax.ejb.EJB;
import javax.ejb.Stateless;
import javax.ws.rs.Consumes;
import javax.ws.rs.GET;
import javax.ws.rs.PUT;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.Produces;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.Response.Status;

import pl.mpiglas.tree.ejb.core.TreeManager;
import pl.mpiglas.tree.model.transfer.TreeNode;

/**
 * Stateless Endpoint for CRUD operations. Delegates calls to
 * {@link TreeManager} and returns domain objects.
 * 
 * @author mpiglas
 *
 */
@Stateless
@Path("tree")
public class TreeService {

	@EJB
	TreeManager treeManager;

	/**
	 * Reads all nodes of tree and creates flat list. Each node contains only
	 * logical reference to its parent (parent's id), not physical one (parent's
	 * object).
	 * 
	 * @return list of nodes, possibly empty.
	 */
	@GET
	@Path("all")
	@Produces("text/json")
	public List<TreeNode> getAll() {
		return treeManager.getAll();
	}

	private boolean checkNode(TreeNode node, boolean idRequired)
	{
		if (node == null)
		{
			return false;
		}
		else if (idRequired && node.getId() == null)
		{
			return false;
		}
		else if (node.getValue() == null)
		{
			return false;
		}
		return true;
	}
	
	/**
	 * Creates new node from provided values and returns updated domain object
	 * with id created from database sequence.
	 * 
	 * @param newNode
	 *            properties of new node
	 * @return {@link Response#ok()} with persisted node if created. Response
	 *         with code {@link Status#BAD_REQUEST} in other case.
	 */
	@PUT
	@Path("create")
	@Produces("text/json")
	@Consumes("text/json")
	public Response create(TreeNode newNode) {
		if (!checkNode(newNode, false))
		{
			return Response.status(Status.BAD_REQUEST).build();
		}
		Optional<TreeNode> created = treeManager.create(newNode);
		if (created.isPresent()) {
			return Response.ok(created.get()).build();
		}
		return Response.status(Status.BAD_REQUEST).build();
	}

	/**
	 * Updates existing node with given properties and returns updated object.
	 * 
	 * @param node
	 *            node to update
	 * @return {@link Response#ok()} if node is updated. Response with code
	 *         {@link Status#BAD_REQUEST} in other case.
	 */
	@PUT
	@Path("update")
	@Consumes("text/json")
	public Response update(TreeNode node) {
		if (!checkNode(node, true))
		{
			return Response.status(Status.BAD_REQUEST).build();
		}
		if (treeManager.update(node)) {
			return Response.ok().build();
		}
		return Response.status(Status.BAD_REQUEST).build();
	}

	
	/**
	 * Deletes node with given id.
	 * 
	 * @param nodeId
	 *            node's id
	 * @return {@link Response#ok()} if node is deleted. Response with code
	 *         {@link Status#BAD_REQUEST} in other case.
	 */
	@GET
	@Path("delete_id/{nodeId}")
	public Response deleteId(@PathParam("nodeId") String nodeId) {
		Long nid;
		try
		{
			nid = Long.parseLong(nodeId);
		}
		catch (NumberFormatException e)
		{
			return Response.status(Status.BAD_REQUEST).build();
		}
		if (treeManager.deleteById(nid)) {
			return Response.ok().build();
		}
		return Response.status(Status.BAD_REQUEST).build();
	}
}
