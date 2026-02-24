WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        COUNT(DISTINCT ph.PostId) AS PostHistoryCount,
        AVG(COALESCE(LENGTH(c.Text), 0)) AS AvgCommentLength
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        u.Reputation > 100 
    GROUP BY 
        u.Id
),
TagStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AvgScore,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
    GROUP BY 
        t.TagName
),
CloseReasons AS (
    SELECT 
        ph.PostId,
        ph.Comment AS CloseReason,
        COUNT(ph.Id) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId, ph.Comment
),
FinalResults AS (
    SELECT 
        ua.UserId,
        ua.QuestionCount,
        ua.AnswerCount,
        ua.TotalBounty,
        ua.PostHistoryCount,
        ua.AvgCommentLength,
        ts.TagName,
        ts.PostCount,
        ts.TotalViews,
        ts.AvgScore,
        ts.LastPostDate,
        cr.CloseReason,
        cr.CloseCount
    FROM 
        UserActivity ua
    LEFT JOIN 
        TagStats ts ON ua.UserId = ts.PostCount 
    LEFT JOIN 
        CloseReasons cr ON ua.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = cr.PostId LIMIT 1) 
)
SELECT 
    UserId,
    QuestionCount,
    AnswerCount,
    TotalBounty,
    PostHistoryCount,
    AvgCommentLength,
    TagName,
    PostCount,
    TotalViews,
    AvgScore,
    LastPostDate,
    CloseReason,
    CloseCount
FROM 
    FinalResults
WHERE 
    COALESCE(PostCount, 0) > 5
ORDER BY 
    TotalBounty DESC,
    AvgScore DESC NULLS LAST
LIMIT 100;