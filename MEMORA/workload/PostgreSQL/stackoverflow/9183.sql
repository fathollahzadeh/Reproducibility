WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 YEAR'
),
HighestRankedPosts AS (
    SELECT 
        PostId, Title, CreationDate, Score, ViewCount, AnswerCount, OwnerDisplayName 
    FROM 
        RankedPosts 
    WHERE 
        Rank <= 5
),
PostVoteCounts AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN VoteTypeId = 6 THEN 1 END) AS CloseVotes
    FROM 
        Votes 
    GROUP BY 
        PostId
)
SELECT 
    h.PostId,
    h.Title,
    h.CreationDate,
    h.Score,
    h.ViewCount,
    h.AnswerCount,
    h.OwnerDisplayName,
    COALESCE(v.UpVotes, 0) AS UpVotes,
    COALESCE(v.DownVotes, 0) AS DownVotes,
    COALESCE(v.CloseVotes, 0) AS CloseVotes
FROM 
    HighestRankedPosts h
LEFT JOIN 
    PostVoteCounts v ON h.PostId = v.PostId
ORDER BY 
    h.Score DESC, h.ViewCount DESC;