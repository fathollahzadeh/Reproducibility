
WITH TagStatistics AS (
    SELECT 
        tag.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(u.Reputation) AS AvgUserReputation
    FROM 
        Tags tag
    JOIN 
        Posts p ON p.Tags LIKE '%' || tag.TagName || '%'
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        tag.TagName
),
ClosedPostStatistics AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS ClosureCount,
        STRING_AGG(DISTINCT ctr.Name, ', ') AS ClosedReasonNames
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes ctr ON ph.Comment::integer = ctr.Id
    WHERE 
        ph.PostHistoryTypeId = 10  
    GROUP BY 
        ph.PostId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    GROUP BY 
        u.Id
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.QuestionCount,
    ts.AnswerCount,
    ts.AvgUserReputation,
    cps.ClosureCount,
    cps.ClosedReasonNames,
    ua.TotalPosts,
    ua.TotalBounties
FROM 
    TagStatistics ts
LEFT JOIN 
    ClosedPostStatistics cps ON ts.TagName IN (SELECT unnest(string_to_array(cps.ClosedReasonNames, ', ')))
LEFT JOIN 
    UserActivity ua ON ua.TotalPosts > 0
ORDER BY 
    ts.PostCount DESC, 
    ts.AvgUserReputation DESC
LIMIT 10;
