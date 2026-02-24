WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        u.DisplayName AS Author,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.LastActivityDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
    GROUP BY 
        p.Id, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        LastActivityDate,
        Score,
        Author,
        CommentCount,
        Upvotes,
        Downvotes
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)

SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.LastActivityDate,
    fp.Score,
    fp.Author,
    fp.CommentCount,
    fp.Upvotes,
    fp.Downvotes,
    (fp.Upvotes - fp.Downvotes) AS NetVotes
FROM 
    FilteredPosts fp
ORDER BY 
    fp.Score DESC, fp.LastActivityDate DESC;