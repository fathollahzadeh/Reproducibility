WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore,
        STRING_AGG(t.TagName, ', ') AS TagsAggregate,
        COALESCE(CAST(SUBSTRING(p.Body FROM '<p>(.*?)</p>') AS TEXT), 'No Body') AS ExtractedBody
    FROM 
        Posts p
    LEFT JOIN 
        UNNEST(STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '> <')) AS tag_ids 
        ON TRUE
    LEFT JOIN 
        Tags t ON t.Id = CAST(tag_ids AS INT)
    WHERE 
        p.LastActivityDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
    GROUP BY 
        p.Id
), 
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS Questions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS Answers,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id 
    WHERE 
        u.Reputation > 1000 AND u.CreationDate < cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        u.Id
),
ClosePostStats AS (
    SELECT 
        ph.UserId,
        COUNT(DISTINCT ph.PostId) AS ClosedPostsCount,
        STRING_AGG(DISTINCT ctr.Name, ', ') AS CloseReasonNames
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes ctr ON ctr.Id = CAST(ph.Comment AS INT)
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.UserId
),
CombinedStats AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.TotalPosts,
        ups.Questions,
        ups.Answers,
        ups.TotalScore,
        COALESCE(cps.ClosedPostsCount, 0) AS ClosedPostsCount,
        COALESCE(cps.CloseReasonNames, 'None') AS CloseReasonNames
    FROM 
        UserPostStats ups
    LEFT JOIN 
        ClosePostStats cps ON cps.UserId = ups.UserId
)
SELECT 
    r.PostId,
    r.Title,
    r.Score,
    r.ViewCount,
    r.CreationDate,
    cs.UserId,
    cs.DisplayName,
    cs.TotalPosts,
    cs.Questions,
    cs.Answers,
    cs.TotalScore,
    cs.ClosedPostsCount,
    cs.CloseReasonNames,
    CASE 
        WHEN r.RankByScore <= 3 THEN 'Top Post' 
        ELSE 'Regular Post' 
    END AS PostCategory,
    CASE 
        WHEN r.Score IS NULL THEN 'Score Unknown'
        WHEN r.Score < 0 THEN 'Post Needs Help'
        ELSE 'Post is Good'
    END AS PostQuality,
    COALESCE(r.ExtractedBody, 'No Content Found') AS PostContentSnippet
FROM 
    RankedPosts r
JOIN 
    CombinedStats cs ON cs.UserId = r.PostId % 10000  
WHERE 
    r.RankByScore <= 10
ORDER BY 
    r.Score DESC, r.CreationDate DESC;