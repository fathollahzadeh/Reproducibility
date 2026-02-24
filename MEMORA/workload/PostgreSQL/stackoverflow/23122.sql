
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionsAsked,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswersGiven,
        MIN(u.CreationDate) AS AccountSince,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
), 
UserStats AS (
    SELECT 
        UserId, 
        DisplayName, 
        Upvotes - Downvotes AS NetVotes,
        QuestionsAsked + AnswersGiven AS TotalEngagement,
        AccountSince,
        ROW_NUMBER() OVER (ORDER BY Upvotes - Downvotes DESC) AS RankNetVotes,
        ROW_NUMBER() OVER (ORDER BY QuestionsAsked + AnswersGiven DESC) AS RankEngagement
    FROM 
        UserActivity
),
ClosedPosts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS ClosedCount,
        MAX(p.ClosedDate) AS LastClosedDate
    FROM 
        Posts p
    WHERE 
        p.ClosedDate IS NOT NULL
    GROUP BY 
        p.OwnerUserId
),
UserRankings AS (
    SELECT 
        u.UserId, 
        u.DisplayName,
        u.NetVotes,
        u.TotalEngagement,
        c.ClosedCount,
        c.LastClosedDate,
        CASE 
            WHEN c.ClosedCount IS NULL THEN 'No Closed Posts' 
            WHEN c.ClosedCount > 5 THEN 'Frequent Closer'
            WHEN c.ClosedCount BETWEEN 1 AND 5 THEN 'Occasional Closer'
            ELSE 'Unknown'
        END AS ClosureBehavior
    FROM 
        UserStats u
    LEFT JOIN 
        ClosedPosts c ON u.UserId = c.OwnerUserId
)
SELECT 
    UR.DisplayName,
    UR.NetVotes,
    UR.TotalEngagement,
    UR.ClosedCount,
    COALESCE(CAST(UR.LastClosedDate AS DATE), DATE '1970-01-01') AS LastClosedDate,
    UR.ClosureBehavior
FROM 
    UserRankings UR
WHERE 
    (UR.NetVotes != 0 OR UR.TotalEngagement > 0)
    AND (UR.TotalEngagement BETWEEN 10 AND 100 OR UR.ClosedCount IS NOT NULL)
ORDER BY 
    UR.NetVotes DESC, 
    UR.TotalEngagement DESC
LIMIT 50;
