WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Owner,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId, Title, Owner, CreationDate, Score, ViewCount, AnswerCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
),
VotesSummary AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN VoteTypeId = 8 THEN 1 END) AS BountyStarts
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Owner,
        tp.CreationDate,
        tp.Score,
        tp.ViewCount,
        tp.AnswerCount,
        COALESCE(vs.UpVotes, 0) AS UpVotes,
        COALESCE(vs.DownVotes, 0) AS DownVotes,
        COALESCE(vs.BountyStarts, 0) AS BountyStarts
    FROM 
        TopPosts tp
    LEFT JOIN 
        VotesSummary vs ON tp.PostId = vs.PostId
)
SELECT 
    pd.Title,
    pd.Owner,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.AnswerCount,
    pd.UpVotes,
    pd.DownVotes,
    pd.BountyStarts,
    EXTRACT(EPOCH FROM (cast('2024-10-01 12:34:56' as timestamp) - pd.CreationDate)) AS AgeInSeconds
FROM 
    PostDetails pd
ORDER BY 
    pd.ViewCount DESC, pd.Score DESC;