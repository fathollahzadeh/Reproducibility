
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.AnswerCount,
        rp.Score,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
),
PostAnalytics AS (
    SELECT 
        trp.PostId,
        trp.Title,
        trp.ViewCount,
        trp.AnswerCount,
        trp.Score,
        trp.OwnerDisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(c.Id) AS CommentCount
    FROM 
        TopRankedPosts trp
    LEFT JOIN 
        Votes v ON v.PostId = trp.PostId
    LEFT JOIN 
        Comments c ON c.PostId = trp.PostId
    GROUP BY 
        trp.PostId, trp.Title, trp.ViewCount, trp.AnswerCount, trp.Score, trp.OwnerDisplayName
)
SELECT 
    pa.PostId,
    pa.Title,
    pa.ViewCount,
    pa.AnswerCount,
    pa.Score,
    pa.OwnerDisplayName,
    pa.UpVotes,
    pa.DownVotes,
    pa.CommentCount,
    (pa.UpVotes - pa.DownVotes) AS NetVotes
FROM 
    PostAnalytics pa
ORDER BY 
    pa.Score DESC, pa.ViewCount DESC;
