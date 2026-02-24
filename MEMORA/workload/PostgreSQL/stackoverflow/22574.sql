
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, u.DisplayName
),
PostsWithVotes AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.Author,
        rc.Upvotes,
        rc.Downvotes,
        rc.Upvotes - COALESCE(rc.Downvotes, 0) AS NetVotes
    FROM 
        RankedPosts rp
    LEFT JOIN (
        SELECT 
            v.PostId,
            SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
            SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
        FROM 
            Votes v
        GROUP BY 
            v.PostId
    ) rc ON rp.PostId = rc.PostId
)
SELECT 
    pwv.PostId,
    pwv.Title,
    pwv.Score,
    pwv.CreationDate,
    pwv.Author,
    pwv.Upvotes,
    pwv.Downvotes,
    pwv.NetVotes,
    CASE 
        WHEN pwv.NetVotes > 0 THEN 'Positive'
        WHEN pwv.NetVotes < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteCategory,
    COALESCE(pwz.CommentCount, 0) AS TotalComments,
    STRING_AGG(DISTINCT pht.Name, ', ') AS PostHistoryTypes
FROM 
    PostsWithVotes pwv
LEFT JOIN 
    PostHistory ph ON ph.PostId = pwv.PostId
LEFT JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
LEFT JOIN 
    (SELECT 
        PostId, COUNT(*) AS CommentCount
     FROM 
        Comments
     GROUP BY 
        PostId) pwz ON pwv.PostId = pwz.PostId
WHERE 
    pwv.NetVotes IS NOT NULL
GROUP BY 
    pwv.PostId, pwv.Title, pwv.Score, pwv.CreationDate, pwv.Author, 
    pwv.Upvotes, pwv.Downvotes, pwv.NetVotes, pwz.CommentCount
HAVING 
    COUNT(DISTINCT ph.Id) > 0 OR COALESCE(pwz.CommentCount, 0) > 0
ORDER BY 
    pwv.NetVotes DESC, pwv.CreationDate ASC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
