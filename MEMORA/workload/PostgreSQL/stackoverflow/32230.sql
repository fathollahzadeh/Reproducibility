WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year' 
        AND p.Score > 0
),

UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS AnswerCount,
        SUM(v.BountyAmount) AS TotalBounty,
        AVG(p.Score) AS AvgScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 2 
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) 
    GROUP BY 
        u.Id
),

TopContributors AS (
    SELECT 
        UserId,
        DisplayName,
        AnswerCount,
        TotalBounty,
        AvgScore,
        RANK() OVER (ORDER BY AnswerCount DESC, TotalBounty DESC) AS ContributorRank
    FROM 
        UserActivity
    WHERE 
        AvgScore > 0
),

TagStatistics AS (
    SELECT 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS TagName,
        COUNT(*) AS TagCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        TagName
),

ClosedPostDetails AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment,
        cr.Name AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10 
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate AS PostCreationDate,
    tp.ViewCount,
    tp.Score,
    t.TagName,
    t.TagCount,
    t.TotalViews,
    u.DisplayName AS TopContributor,
    u.AvgScore AS ContributorAvgScore,
    c.CloseReason,
    c.CreationDate AS CloseDate
FROM 
    RankedPosts tp
JOIN 
    TagStatistics t ON true 
JOIN 
    TopContributors u ON u.UserId = tp.PostId  
LEFT JOIN 
    ClosedPostDetails c ON c.PostId = tp.PostId
WHERE 
    tp.ScoreRank <= 10 AND 
    (c.CloseReason IS NULL OR c.CloseReason != 'Exact Duplicate')
ORDER BY 
    tp.Score DESC, t.TagName;