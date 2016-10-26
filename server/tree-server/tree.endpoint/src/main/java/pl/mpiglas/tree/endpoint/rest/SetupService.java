package pl.mpiglas.tree.endpoint.rest;

import javax.ejb.EJB;
import javax.ejb.Stateless;
import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;

import pl.mpiglas.tree.ejb.core.SetupManager;

/**
 * Helper bean initializes or resets sample tree.
 * @author mpiglas
 *
 */
@Stateless
@Path("setup")
public class SetupService {

	@EJB
	SetupManager sm;
	
	@GET
	@Path("init")
	@Produces("text/json")
	public String initStorage()
	{
		sm.initSampleTree();
		return "ok";
	}
	
	@GET
	@Path("reset")
	public String resetStorage()
	{
		sm.clearDb();
		sm.initSampleTree();
		return "ok";
	}
	
}
