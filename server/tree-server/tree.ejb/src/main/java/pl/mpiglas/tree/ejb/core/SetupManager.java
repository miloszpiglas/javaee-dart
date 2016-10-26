package pl.mpiglas.tree.ejb.core;

import java.util.Optional;

import javax.ejb.EJB;
import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;

import pl.mpiglas.tree.model.transfer.TreeNode;

/**
 * Helper bean inits or resets sample tree.
 * @author mpiglas
 *
 */
@Stateless
public class SetupManager {
	
	@EJB
	TreeManager tm;
	
	@PersistenceContext(name = "storageUnit")
	EntityManager em;
	
	/**
	 * Inits sample tree.
	 */
	public void initSampleTree()
	{
		Optional<TreeNode> node = tm.create(TreeNode.newNode(null, 10d));
		createChildren(node.get(), 2, 1);
	}
	
	private void createChildren(TreeNode parent, int level, double mul)
	{
		Optional<TreeNode> sub1 = tm.create(TreeNode.newNode(parent.getId(), mul * Math.pow(10, level)));
		Optional<TreeNode> sub2 = tm.create(TreeNode.newNode(parent.getId(), (mul+1) * Math.pow(10, level)));
		if (level < 5)
		{
			createChildren(sub1.get(), level+1, mul);
			createChildren(sub2.get(), level+1, mul);
		}
	}
	
	/**
	 * Remove all nodes from tree.
	 */
	public void clearDb()
	{
		em.createQuery("DELETE FROM TreeNodeEntity e").executeUpdate();
	}
	
	
}
