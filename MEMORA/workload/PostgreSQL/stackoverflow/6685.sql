
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(c.Id) DESC) AS Rank,
        u.DisplayName AS AuthorDisplayName
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, u.DisplayName, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CommentCount,
        Upvotes,
        Downvotes,
        AuthorDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
)
SELECT 
    t.Title,
    t.AuthorDisplayName,
    t.CommentCount,
    t.Upvotes,
    t.Downvotes,
    (t.Upvotes - t.Downvotes) AS NetScore,
    CASE 
        WHEN t.Upvotes > t.Downvotes THEN 'Positive'
        WHEN t.Upvotes < t.Downvotes THEN 'Negative'
        ELSE 'Neutral'
    END AS Sentiment
FROM 
    TopPosts t
ORDER BY 
    NetScore DESC;
