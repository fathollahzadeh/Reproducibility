WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
        AND p.PostTypeId = 1
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        Score, 
        CreationDate, 
        ViewCount, 
        AnswerCount, 
        OwnerUserId, 
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
),
PostVoteCounts AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
)
SELECT 
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    tp.OwnerDisplayName,
    COALESCE(pvc.UpVotes, 0) AS UpVotes,
    COALESCE(pvc.DownVotes, 0) AS DownVotes
FROM 
    TopPosts tp
LEFT JOIN 
    PostVoteCounts pvc ON tp.PostId = pvc.PostId
ORDER BY 
    tp.Score DESC,
    tp.ViewCount DESC;