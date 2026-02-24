
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        COALESCE(pv.UpVoteCount, 0) AS UpVotes,
        COALESCE(cv.CloseCount, 0) AS CloseCount,
        COALESCE(ac.AcceptedAnswerCount, 0) AS AcceptedAnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS UpVoteCount 
        FROM 
            Votes 
        WHERE 
            VoteTypeId = 2 
        GROUP BY 
            PostId
    ) pv ON p.Id = pv.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CloseCount 
        FROM 
            PostHistory 
        WHERE 
            PostHistoryTypeId = 10 
        GROUP BY 
            PostId
    ) cv ON p.Id = cv.PostId
    LEFT JOIN (
        SELECT 
            ParentId AS PostId, 
            COUNT(*) AS AcceptedAnswerCount 
        FROM 
            Posts 
        WHERE 
            PostTypeId = 2 
        GROUP BY 
            ParentId
    ) ac ON p.Id = ac.PostId
    WHERE 
        p.PostTypeId = 1 
),

UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        SUM(u.Views) AS TotalViews
    FROM 
        Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    rp.OwnerUserId,
    u.DisplayName,
    COUNT(DISTINCT rp.PostId) AS TotalPosts,
    SUM(rp.UpVotes) AS TotalPostUpVotes,
    SUM(rp.CloseCount) AS TotalPostCloses,
    SUM(rp.AcceptedAnswerCount) AS TotalAcceptedAnswers,
    us.QuestionCount,
    us.BadgeCount,
    us.TotalUpVotes,
    us.TotalDownVotes,
    us.TotalViews,
    ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT rp.PostId) DESC) AS UserRank
FROM 
    RankedPosts rp
JOIN Users u ON rp.OwnerUserId = u.Id
JOIN UserStats us ON u.Id = us.UserId
WHERE
    rp.RecentPostRank = 1
GROUP BY 
    rp.OwnerUserId, u.DisplayName, us.QuestionCount, us.BadgeCount, us.TotalUpVotes, us.TotalDownVotes, us.TotalViews
HAVING 
    COUNT(DISTINCT rp.PostId) > 0
ORDER BY 
    UserRank;
