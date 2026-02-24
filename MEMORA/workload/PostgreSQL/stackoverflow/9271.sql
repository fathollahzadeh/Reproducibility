WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '90 days'
),
TopRankedPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp 
    WHERE 
        rp.Rank <= 5
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
PostVoteCounts AS (
    SELECT
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM
        Votes v
    GROUP BY
        v.PostId
)
SELECT
    trp.PostId,
    trp.Title,
    trp.CreationDate,
    trp.Score,
    trp.ViewCount,
    trp.AnswerCount,
    trp.CommentCount AS PostCommentCount,
    COALESCE(pc.CommentCount, 0) AS TotalComments,
    COALESCE(pvc.UpVotes, 0) AS UpVotes,
    COALESCE(pvc.DownVotes, 0) AS DownVotes,
    COALESCE(pvc.TotalVotes, 0) AS TotalVotes,
    trp.OwnerDisplayName
FROM 
    TopRankedPosts trp
LEFT JOIN 
    PostComments pc ON trp.PostId = pc.PostId
LEFT JOIN 
    PostVoteCounts pvc ON trp.PostId = pvc.PostId
ORDER BY 
    trp.Score DESC, trp.ViewCount DESC;