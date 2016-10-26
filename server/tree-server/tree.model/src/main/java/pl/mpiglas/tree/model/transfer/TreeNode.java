package pl.mpiglas.tree.model.transfer;

import java.io.Serializable;

import pl.mpiglas.tree.model.entity.TreeNodeEntity;

/**
 * Domain representation of tree's node. These objects are used to transfer
 * properties from and to client via REST services.
 * 
 * @author mpiglas
 *
 */
public class TreeNode implements Serializable {

	private static final long serialVersionUID = 728765252154735833L;
	private Long id;
	private Long parentId;
	private Double value;

	public Long getId() {
		return id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	public Long getParentId() {
		return parentId;
	}

	public void setParentId(Long parentId) {
		this.parentId = parentId;
	}

	public Double getValue() {
		return value;
	}

	public void setValue(Double value) {
		this.value = value;
	}

	/**
	 * Maps entity to domain object.
	 * 
	 * @param entity
	 *            node entity
	 * @return domain object.
	 */
	public static TreeNode fromEntity(TreeNodeEntity entity) {
		TreeNode node = new TreeNode();
		node.setId(entity.getId());
		if (entity.getParent() != null) {
			node.setParentId(entity.getParent().getId());
		}
		node.setValue(entity.getNodeValue());
		return node;
	}
	
	/**
	 * Creates new node for given parent.
	 * @param parentId id of parent
	 * @param value value
	 * @return new node
	 */
	public static TreeNode newNode(Long parentId, Double value)
	{
		TreeNode node = new TreeNode();
		node.setParentId(parentId);
		node.setValue(value);
		return node;
	}

	@Override
	public String toString() {
		return "TreeNode [id=" + id + ", parentId=" + parentId + ", value="
				+ value + "]";
	}

}
