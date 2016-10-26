package pl.mpiglas.tree.model.entity;

import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.NamedQueries;
import javax.persistence.NamedQuery;
import javax.persistence.OneToOne;
import javax.persistence.Table;

/**
 * Entity represents tree and its nodes.
 * 
 * @author mpiglas
 *
 */
@Entity
@Table(name = "TREE_NODES")
@NamedQueries({
		@NamedQuery(name = TreeNodeEntity.FIND_ALL_QUERY, query = "SELECT e FROM TreeNodeEntity e"),
		@NamedQuery(name = TreeNodeEntity.FIND_NODE_QUERY, query = "SELECT e FROM TreeNodeEntity e WHERE e.id = :nodeId"),
		@NamedQuery(name = TreeNodeEntity.FIND_CHILDREN, query = "SELECT e from TreeNodeEntity e WHERE e.parent.id = :nodeId"),
		@NamedQuery(name = TreeNodeEntity.FIND_ROOT, query = "SELECT e from TreeNodeEntity e WHERE e.parent = null")
		
})
public class TreeNodeEntity {

	/**
	 * Identifier of query that fetches all nodes from database.
	 */
	public static final String FIND_ALL_QUERY = "TreeNodeEntity.findAll";
	/**
	 * Identifier of query that looks for node with given id.
	 */
	public static final String FIND_NODE_QUERY = "TreeNodeEntity.findNode";
	public static final String NODE_ID_PARAM = "nodeId";
	/**
	 * Identifier of query that fetches all children of given node.
	 */
	public static final String FIND_CHILDREN = "TreeNodeEntity.findChildren";
	
	public static final String FIND_ROOT = "TreeNodeEntity.findRoot";

	@GeneratedValue(strategy = GenerationType.AUTO)
	@Id
	private Long id;

	@OneToOne
	private TreeNodeEntity parent;

	@Column(nullable = false, name = "NODE_VALUE")
	private Double nodeValue;

	public Long getId() {
		return id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	public TreeNodeEntity getParent() {
		return parent;
	}

	public void setParent(TreeNodeEntity parent) {
		this.parent = parent;
	}

	public Double getNodeValue() {
		return nodeValue;
	}

	public void setNodeValue(Double nodeValue) {
		this.nodeValue = nodeValue;
	}

	@Override
	public String toString() {
		return "TreeNodeEntity [id=" + id + ", parent=" + parent
				+ ", nodeValue=" + nodeValue + "]";
	}
}
