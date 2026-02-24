
WITH PopularPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ARRAY_AGG(t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Tags t ON t.ExcerptPostId = p.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
        AND p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
    ORDER BY 
        p.Score DESC
    LIMIT 10
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        Upvotes DESC
    LIMIT 5
)
SELECT 
    pp.Title,
    pp.CreationDate,
    pp.Score,
    pp.ViewCount,
    pp.CommentCount,
    tu.DisplayName AS TopUser,
    tu.Upvotes,
    tu.Downvotes,
    pp.Tags
FROM 
    PopularPosts pp
JOIN 
    TopUsers tu ON pp.Id IN (
        SELECT PostId 
        FROM Votes 
        WHERE UserId = tu.Id AND VoteTypeId = 2
    )
ORDER BY 
    pp.Score DESC, pp.ViewCount DESC;
