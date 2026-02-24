
WITH PostCounts AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.AnswerCount) AS TotalAnswers,
        SUM(p.CommentCount) AS TotalComments
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(v.BountyAmount) AS TotalBounty,
        SUM(CASE WHEN v.UserId IS NOT NULL AND v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes, 
        SUM(CASE WHEN v.UserId IS NOT NULL AND v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes 
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    pc.PostType,
    pc.PostCount,
    pc.TotalScore,
    pc.TotalViews,
    pc.TotalAnswers,
    pc.TotalComments,
    ue.UserId,
    ue.DisplayName,
    ue.BadgeCount,
    ue.TotalBounty,
    ue.UpVotes,
    ue.DownVotes
FROM 
    PostCounts pc
JOIN 
    UserEngagement ue ON ue.UserId IS NOT NULL
ORDER BY 
    pc.PostCount DESC, ue.BadgeCount DESC;
