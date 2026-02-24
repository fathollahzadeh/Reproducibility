
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        t.TagName
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        UNNEST(string_to_array(p.Tags, ',')) AS tag ON tag IS NOT NULL
    JOIN 
        Tags t ON t.TagName = TRIM(tag)  
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    ORDER BY 
        p.CreationDate DESC
),
VoteSummary AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostAnalytics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        rp.FavoriteCount,
        vs.UpVotes,
        vs.DownVotes,
        rp.TagName
    FROM 
        RecentPosts rp
    LEFT JOIN 
        VoteSummary vs ON rp.PostId = vs.PostId
)
SELECT 
    pa.OwnerDisplayName,
    pa.Title,
    pa.CreationDate,
    pa.Score,
    pa.ViewCount,
    pa.AnswerCount,
    pa.CommentCount,
    pa.FavoriteCount,
    pa.UpVotes,
    pa.DownVotes,
    STRING_AGG(DISTINCT pa.TagName, ', ') AS Tags
FROM 
    PostAnalytics pa
GROUP BY 
    pa.OwnerDisplayName, pa.Title, pa.CreationDate, pa.Score, pa.ViewCount, pa.AnswerCount, pa.CommentCount, pa.FavoriteCount, pa.UpVotes, pa.DownVotes
ORDER BY 
    pa.CreationDate DESC
LIMIT 100;
