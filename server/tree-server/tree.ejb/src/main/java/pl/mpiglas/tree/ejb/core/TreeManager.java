package pl.mpiglas.tree.ejb.core;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

import javax.annotation.PostConstruct;
import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.persistence.TypedQuery;

import org.jboss.logging.Logger;

import pl.mpiglas.tree.model.entity.TreeNodeEntity;
import pl.mpiglas.tree.model.transfer.TreeNode;

/**
 * Manages Tree that is represented as JPA entities. Provides operations for
 * adding new nodes, updating and deleting.
 * 
 * Tree is built from entities that represents tree nodes. Each node, except
 * tree's root, contains reference for its parent.
 * 
 * @author mpiglas
 *
 */
@Stateless
public class TreeManager {

	Logger logger;

	@PersistenceContext(name = "storageUnit")
	EntityManager em;

	/**
	 * Inits bean.
	 */
	@PostConstruct
	public void init() {
		logger = Logger.getLogger(TreeManager.class);
	}

	private TreeNodeEntity getNode(long id, boolean detach) {
		TypedQuery<TreeNodeEntity> query = em.createNamedQuery(
				TreeNodeEntity.FIND_NODE_QUERY, TreeNodeEntity.class);
		query.setParameter(TreeNodeEntity.NODE_ID_PARAM, id);
		List<TreeNodeEntity> nodes = query.getResultList();
		if (nodes.isEmpty()) {
			return null;
		}
		TreeNodeEntity node = nodes.get(0);
		if (detach) {
			em.detach(node);
		}
		return node;
	}

	private boolean isRootExist() {
		logger.info("Checking root");
		List<TreeNodeEntity> rootList = em.createNamedQuery(
				TreeNodeEntity.FIND_ROOT, TreeNodeEntity.class).getResultList();
		return !rootList.isEmpty();
	}

	/**
	 * Creates new entity representing tree's node. If node is not a root and
	 * parent doesn't exist or node doesn't have parent and root already exist
	 * entity is not created.
	 * 
	 * @param newNode
	 *            new node that should be added to tree.
	 * @return {@link Optional} with created object or empty if object wasn't
	 *         created.
	 */
	public Optional<TreeNode> create(TreeNode newNode) {
		TreeNodeEntity entity = new TreeNodeEntity();
		entity.setNodeValue(newNode.getValue());
		if (newNode.getParentId() != null) {
			TreeNodeEntity parent = getNode(newNode.getParentId(), true);
			if (parent == null) {
				return Optional.empty();
			}
			entity.setParent(getNode(newNode.getParentId(), true));
		} else if (isRootExist()) {
			logger.warnv("Second root can't be created {0}", newNode);
			// Tree can have only single root
			return Optional.empty();

		}
		em.persist(entity);
		logger.infov("Entity {0} created", entity);
		return Optional.of(TreeNode.fromEntity(entity));
	}

	/**
	 * Reads all entities from database and transforms to domain objects.
	 * 
	 * @return list of entities, possibly empty.
	 */
	public List<TreeNode> getAll() {
		List<TreeNodeEntity> result = em.createNamedQuery(
				TreeNodeEntity.FIND_ALL_QUERY, TreeNodeEntity.class)
				.getResultList();
		logger.info("Reading all nodes");
		return result.stream().map(TreeNode::fromEntity)
				.collect(Collectors.toList());
	}

	/**
	 * Updates node with given properties.
	 * 
	 * @param node
	 *            properties of node
	 * @return true if update finished with success.
	 */
	public boolean update(TreeNode node) {

		TreeNodeEntity entity = getNode(node.getId(), false);
		if (entity != null) {
			entity.setNodeValue(node.getValue());
			em.merge(entity);
			logger.infov("Entity updated: {0}  ", entity);
			return true;
		} else {
			logger.warnv("Entity  {0} not found", node.getId());
		}
		return false;
	}

	private List<TreeNodeEntity> getChildren(Long nodeId) {
		TypedQuery<TreeNodeEntity> query = em.createNamedQuery(
				TreeNodeEntity.FIND_CHILDREN, TreeNodeEntity.class);
		query.setParameter(TreeNodeEntity.NODE_ID_PARAM, nodeId);
		return query.getResultList();
	}

	/**
	 * Deletes node and its children.
	 * 
	 * @param node
	 *            Entity representing tree's node.
	 */
	private void deleteWithChildren(TreeNodeEntity node) {
		for (TreeNodeEntity e : getChildren(node.getId())) {
			deleteWithChildren(e);
		}
		logger.info("Delete node " + node.getId());
		em.remove(node);
	}

	/**
	 * Deletes node with given id and its children. If node represents tree's
	 * root, all nodes will be removed.
	 * 
	 * @param nodeId
	 *            node's id
	 * @return true if node was deleted.
	 */
	public boolean deleteById(Long nodeId) {
		TreeNodeEntity entity = getNode(nodeId, false);
		if (entity != null) {
			deleteWithChildren(entity);
		} else {
			logger.warn("Entity " + nodeId + " not found");
			return false;
		}
		return true;
	}

}
