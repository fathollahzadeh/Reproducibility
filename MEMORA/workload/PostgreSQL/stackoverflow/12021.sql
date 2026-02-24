WITH Post_Vote_Summary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.PostTypeId
),
Post_Comment_Summary AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS TotalComments
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    pvs.PostId,
    pvs.Title,
    pvs.PostTypeId,
    pvs.TotalVotes,
    pvs.Upvotes,
    pvs.Downvotes,
    COALESCE(pcs.TotalComments, 0) AS TotalComments
FROM 
    Post_Vote_Summary pvs
LEFT JOIN 
    Post_Comment_Summary pcs ON pvs.PostId = pcs.PostId
ORDER BY 
    pvs.TotalVotes DESC, 
    pvs.Upvotes DESC, 
    pvs.Downvotes ASC;