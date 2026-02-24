WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank = 1
),
PostVoteCounts AS (
    SELECT 
        v.PostId,
        COUNT(*) FILTER (WHERE v.VoteTypeId = 2) AS Upvotes,
        COUNT(*) FILTER (WHERE v.VoteTypeId = 3) AS Downvotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostWithVoteAndCommentStats AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.ViewCount,
        tp.Score,
        tp.CreationDate,
        tp.AnswerCount,
        COALESCE(pvc.Upvotes, 0) AS TotalUpvotes,
        COALESCE(pvc.Downvotes, 0) AS TotalDownvotes,
        COALESCE(pc.CommentCount, 0) AS TotalComments
    FROM 
        TopPosts tp
    LEFT JOIN 
        PostVoteCounts pvc ON tp.PostId = pvc.PostId
    LEFT JOIN 
        PostComments pc ON tp.PostId = pc.PostId
)
SELECT 
    pwvcs.PostId,
    pwvcs.Title,
    pwvcs.ViewCount,
    pwvcs.Score,
    pwvcs.TotalUpvotes,
    pwvcs.TotalDownvotes,
    pwvcs.TotalComments,
    (pwvcs.TotalUpvotes - pwvcs.TotalDownvotes) AS NetScore,
    (EXTRACT(EPOCH FROM (cast('2024-10-01 12:34:56' as timestamp) - pwvcs.CreationDate)) / 86400) AS AgeInDays
FROM 
    PostWithVoteAndCommentStats pwvcs
WHERE 
    pwvcs.TotalComments > 0
ORDER BY 
    NetScore DESC, AgeInDays ASC
LIMIT 10;