package pl.mpiglas.tree.endpoint.rest;

import javax.annotation.PostConstruct;
import javax.ejb.Stateless;
import javax.websocket.OnMessage;
import javax.websocket.Session;
import javax.websocket.server.ServerEndpoint;

import org.jboss.logging.Logger;

/**
 * Socket listen for events from client when it performs update of model and
 * forwards it to other sessions.
 * 
 * @author mpiglas
 *
 */
@Stateless
@ServerEndpoint("/changeEvent")
public class ChangeEventSocket {
	private Logger logger;

	/**
	 * Inits bean.
	 */
	@PostConstruct
	public void init() {
		logger = Logger.getLogger(ChangeEventSocket.class);
	}

	@OnMessage
	public void modelChanged(String message, Session session) {
		logger.info("New message " + message);
		for (Session so : session.getOpenSessions()) {
			if (!so.equals(session)) {
				so.getAsyncRemote().sendText("reload");
			}
		}

	}

}
