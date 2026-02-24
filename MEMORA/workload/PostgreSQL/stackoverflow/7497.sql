
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT c.Id) DESC, p.LastActivityDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.LastActivityDate, u.DisplayName
),
TopRankedPosts AS (
    SELECT 
        Rank, PostId, Title, CreationDate, LastActivityDate, OwnerDisplayName, TotalComments, TotalUpVotes, TotalDownVotes
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    trp.PostId,
    trp.Title,
    trp.CreationDate,
    trp.LastActivityDate,
    trp.OwnerDisplayName,
    trp.TotalComments,
    trp.TotalUpVotes,
    trp.TotalDownVotes,
    (trp.TotalUpVotes - trp.TotalDownVotes) AS NetVotes,
    EXTRACT(EPOCH FROM (TIMESTAMP '2024-10-01 12:34:56' - trp.LastActivityDate)) AS SecondsSinceLastActivity
FROM 
    TopRankedPosts trp
ORDER BY 
    NetVotes DESC, 
    SecondsSinceLastActivity ASC;
