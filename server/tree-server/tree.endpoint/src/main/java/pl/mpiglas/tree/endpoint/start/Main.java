package pl.mpiglas.tree.endpoint.start;

import org.wildfly.swarm.Swarm;
import org.wildfly.swarm.logging.LoggingFraction;
import org.wildfly.swarm.undertow.UndertowFraction;

/**
 * Entry point for Wildfly Swarm container. Applies non-default settings.
 * @author mpiglas
 *
 */
public class Main {
	public static void main(String[] args) throws Exception {
		Swarm container = new Swarm();
		// Container will be listeneing on port 9080
		UndertowFraction uf = UndertowFraction.createDefaultFraction()
				.httpPort(9080);
		container.fraction(uf).fraction(
				LoggingFraction.createDefaultLoggingFraction());
		container.start().deploy(container.createDefaultDeployment());
	}
}
