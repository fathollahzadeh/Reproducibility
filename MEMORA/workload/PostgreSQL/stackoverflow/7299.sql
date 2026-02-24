
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
        ROW_NUMBER() OVER (ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        AnswerCount,
        CommentCount,
        FavoriteCount,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 50
),
PostVoteCounts AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVoteCount
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostWithVoteCounts AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.Score,
        tp.ViewCount,
        tp.AnswerCount,
        tp.CommentCount,
        tp.FavoriteCount,
        tp.OwnerDisplayName,
        COALESCE(pvc.UpVoteCount, 0) AS UpVoteCount,
        COALESCE(pvc.DownVoteCount, 0) AS DownVoteCount
    FROM 
        TopPosts tp
    LEFT JOIN 
        PostVoteCounts pvc ON tp.PostId = pvc.PostId
)

SELECT 
    pwc.PostId,
    pwc.Title,
    pwc.CreationDate,
    pwc.Score,
    pwc.ViewCount,
    pwc.AnswerCount,
    pwc.CommentCount,
    pwc.FavoriteCount,
    pwc.OwnerDisplayName,
    pwc.UpVoteCount,
    pwc.DownVoteCount,
    ROUND((pwc.UpVoteCount * 1.0 / NULLIF(pwc.UpVoteCount + pwc.DownVoteCount, 0)) * 100, 2) AS UpvotePercentage
FROM 
    PostWithVoteCounts pwc
ORDER BY 
    pwc.Score DESC, pwc.CreationDate DESC;
