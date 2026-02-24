
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS RowNum,
        ARRAY_AGG(t.TagName) AS TagsArray
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON p.Tags LIKE '%' || t.TagName || '%'
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotesCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotesCount
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 month'
    GROUP BY 
        v.PostId
),
PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.TagsArray,
        rp.CreationDate,
        COALESCE(rv.UpVotesCount, 0) AS UpVotes,
        COALESCE(rv.DownVotesCount, 0) AS DownVotes,
        rp.Score,
        rp.ViewCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentVotes rv ON rp.PostId = rv.PostId
),
RankedMetrics AS (
    SELECT 
        *,
        CASE 
            WHEN UpVotes - DownVotes > 0 THEN 'Positive'
            WHEN UpVotes - DownVotes < 0 THEN 'Negative'
            ELSE 'Neutral'
        END AS VoteSentiment,
        RANK() OVER (ORDER BY Score DESC) AS ScoreRank
    FROM 
        PostMetrics
)
SELECT 
    rm.*,
    (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = rm.PostId AND ph.CreationDate > rm.CreationDate) AS PostHistoryCount,
    (SELECT STRING_AGG(DISTINCT CONCAT('Tag: ', tag), '; ') FROM UNNEST(rm.TagsArray) AS tag) AS FormattedTags,
    CASE 
        WHEN u.LastAccessDate IS NULL OR u.LastAccessDate < rm.CreationDate THEN 'Inactive'
        ELSE 'Active'
    END AS UserActivityStatus
FROM 
    RankedMetrics rm
JOIN 
    Users u ON rm.PostId = u.Id
WHERE 
    rm.ScoreRank <= 10 
ORDER BY 
    rm.Score DESC, 
    VoteSentiment ASC NULLS LAST;
