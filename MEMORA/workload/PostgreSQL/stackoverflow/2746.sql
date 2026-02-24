WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.AnswerCount,
        COALESCE(u.DisplayName, 'Anonymous') AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostVoteStats AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS Downvotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
CommentStats AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
CombinedStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.AnswerCount,
        rp.OwnerDisplayName,
        COALESCE(pvs.Upvotes, 0) AS Upvotes,
        COALESCE(pvs.Downvotes, 0) AS Downvotes,
        COALESCE(cs.CommentCount, 0) AS CommentCount,
        rp.Rank
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostVoteStats pvs ON rp.PostId = pvs.PostId
    LEFT JOIN 
        CommentStats cs ON rp.PostId = cs.PostId
)

SELECT 
    cs.PostId,
    cs.Title,
    cs.Score,
    cs.AnswerCount,
    cs.OwnerDisplayName,
    cs.Upvotes,
    cs.Downvotes,
    cs.CommentCount,
    CASE 
        WHEN cs.Rank = 1 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostCategory
FROM 
    CombinedStats cs
WHERE 
    cs.Upvotes > cs.Downvotes
ORDER BY 
    cs.Score DESC, cs.Upvotes DESC
LIMIT 10;