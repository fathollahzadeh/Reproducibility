WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        COALESCE(av.Reputation, 0) AS AverageVote,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY COUNT(c.Id) DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT PostId, AVG(CASE WHEN VoteTypeId = 2 THEN 1 ELSE -1 END) AS Reputation
         FROM Votes
         GROUP BY PostId) av ON p.Id = av.PostId
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.Body, p.Tags, p.CreationDate, av.Reputation
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.CreationDate,
    rp.OwnerName,
    rp.AverageVote,
    rp.CommentCount
FROM 
    RankedPosts rp
WHERE 
    rp.TagRank = 1
ORDER BY 
    rp.AverageVote DESC,
    rp.CommentCount DESC
LIMIT 10;