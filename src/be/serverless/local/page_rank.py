import networkx as nx
from networkx import NetworkXError
import json
import matplotlib.pyplot as plt


def ingest(filename):
    MG = nx.DiGraph()
    f = open(filename)
    data = json.load(f)
    for page, data in data["pages"].items():
        for link in data["backlinks"]:
            MG.add_edge(page, link, weight=1)
    nx.draw(MG, with_labels=True)
    plt.show()
    undirected_MG = MG.to_undirected()
    print([c for c in sorted(nx.connected_components(undirected_MG), key=len, reverse=True)])

    return MG

def initilize_node_weights(G, nstart):
    if nstart is None:
        return dict.fromkeys(G, 1.0 / G.number_of_nodes())
    total_weight = sum(nstart.values() for n in G.nodes())
    return {k: v / total_weight for k, v in nstart.items()}

def initialize_personalization(G, personalization):
    if personalization is None:
        return dict.fromkeys(G, 1.0 / G.number_of_nodes())
    missing_nodes = set(G) - set(personalization)
    if missing_nodes:
        raise NetworkXError('Personalization dictionary must have a value for every node')
    total_weight = sum(personalization.values())
    return {k: v / total_weight for k, v in personalization.items()}

def initialize_dangling_weights(G, dangling, personalization):
    if dangling is None:
        return personalization
    missing_nodes = set(G) - set(dangling)
    if missing_nodes:
        raise NetworkXError('dangling node dictionary must have a value for every node')
    total_weight = sum(dangling.values())
    return {k: v / total_weight for k, v in dangling.items()}

def calculate_pagerank(W, x, dangline_nodes, dangling_weights, weight, alpha, p, max_iter, tol, G):
    for _ in range(max_iter):
        x_last = x
        x = dict.fromkeys(x_last.keys(), 0)
        dangle_sum = alpha * sum(x_last[n] for n in dangline_nodes)
        for n in x:
            for nbr in W[n]:
                x[nbr] += alpha * x_last[n] * W[n][nbr][weight]
            x[n] += dangle_sum + dangling_weights[n] + (1.0 - alpha) * p[n]
        error = sum(abs(x[n] - x_last[n] for n in x))
        if error < G.number_of_nodes() * tol:
            return x
    raise NetworkXError('pagerank: power iteration failed to converge in %d iterations' % max_iter)    

def pagerank(G, alpha=0.85, personalization=None, max_iter=100, tol=1.0e-6, nstart=None, weight='weight', dangling=None):
    if len(G) == 0:
        return {}
    
    D = G if G.is_directed() else G.to_directed()
    W = nx.stochastic_graph(D, weight=weight)
    x = initilize_node_weights(W, nstart)
    p = initialize_personalization(W, personalization)
    dangling_weights = initialize_dangling_weights(W, dangling, personalization)
    dangling_nodes = [n for n in W if W.out_degree(n, weight=weight) == 0.0]

    return calculate_pagerank(W, x, dangling_nodes, dangling_weights, weight, alpha, p, max_iter, tol, G)


Graph = ingest("../src/be/serverless/lambda/test_10000.json")
print(pagerank(Graph))
print(nx.pagerank(Graph))