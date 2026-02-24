WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
        AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        Score,
        ViewCount,
        CreationDate,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        TagRank <= 5  
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
PostWithComments AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Body,
        tp.Score,
        tp.ViewCount,
        tp.CreationDate,
        tp.OwnerDisplayName,
        COALESCE(pc.CommentCount, 0) AS CommentCount
    FROM 
        TopPosts tp
    LEFT JOIN 
        PostComments pc ON tp.PostId = pc.PostId
),
PostVoteSummary AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    pwc.PostId,
    pwc.Title,
    pwc.Body,
    pwc.Score,
    pwc.ViewCount,
    pwc.CreationDate,
    pwc.OwnerDisplayName,
    pwc.CommentCount,
    pvs.UpVotes,
    pvs.DownVotes
FROM 
    PostWithComments pwc
JOIN 
    PostVoteSummary pvs ON pwc.PostId = pvs.PostId
ORDER BY 
    pwc.Score DESC, pwc.CommentCount DESC, pwc.ViewCount DESC;