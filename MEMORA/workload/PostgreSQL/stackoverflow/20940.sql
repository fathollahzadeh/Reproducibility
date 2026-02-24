
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS Rank,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p 
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        LATERAL (
            SELECT 
                UNNEST(string_to_array(p.Tags, '><')) AS TagName
        ) AS t ON TRUE
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, pt.Name
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(c.Id) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Id
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        ue.UpVotes,
        ue.DownVotes,
        ue.CommentCount,
        COALESCE(ue.UpVotes, 0) AS EffectiveUpVotes,
        COALESCE(ROUND((CAST(rp.Score AS numeric) / NULLIF(rp.ViewCount, 0)) * 100, 2), 0) AS ScorePerView
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserEngagement ue ON ue.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.EffectiveUpVotes,
    ps.DownVotes,
    ps.CommentCount,
    ps.ScorePerView,
    CASE 
        WHEN ps.ScorePerView > 5 THEN 'Highly Engaged'
        WHEN ps.ScorePerView > 2 THEN 'Moderately Engaged'
        ELSE 'Low Engagement' 
    END AS EngagementLevel,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    PostStatistics ps
JOIN 
    Posts p ON ps.PostId = p.Id
LEFT JOIN 
    LATERAL (
        SELECT 
            UNNEST(string_to_array(p.Tags, '><')) AS TagName
    ) AS t ON TRUE
WHERE 
    ps.ScorePerView IS NOT NULL
GROUP BY 
    ps.PostId, ps.Title, ps.CreationDate, ps.Score, ps.ViewCount, ps.EffectiveUpVotes, ps.DownVotes, ps.CommentCount, ps.ScorePerView
ORDER BY 
    ps.ScorePerView DESC, ps.CreationDate DESC
LIMIT 100;
