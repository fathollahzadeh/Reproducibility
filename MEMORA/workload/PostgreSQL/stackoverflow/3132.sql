
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsAsked,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersGiven,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesReceived
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        QuestionsAsked,
        AnswersGiven,
        UpVotesReceived,
        DownVotesReceived,
        RANK() OVER (ORDER BY UpVotesReceived DESC) AS UpvoteRank
    FROM 
        UserActivity
),
UsersWithBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgesCount,
        MAX(b.Class) AS MaxBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
FinalReport AS (
    SELECT 
        r.UserId,
        r.DisplayName,
        r.TotalPosts,
        r.QuestionsAsked,
        r.AnswersGiven,
        r.UpVotesReceived,
        r.DownVotesReceived,
        COALESCE(b.BadgesCount, 0) AS BadgesCount,
        CASE 
            WHEN b.MaxBadgeClass IS NULL THEN 'None'
            WHEN b.MaxBadgeClass = 1 THEN 'Gold'
            WHEN b.MaxBadgeClass = 2 THEN 'Silver'
            ELSE 'Bronze'
        END AS MaxBadgeClass
    FROM 
        RankedUsers r
    LEFT JOIN 
        UsersWithBadges b ON r.UserId = b.UserId
)

SELECT 
    *,
    CASE 
        WHEN TotalPosts = 0 THEN 'No Activity'
        WHEN UpVotesReceived > DownVotesReceived THEN 'Positive Contributor'
        ELSE 'Needs Improvement'
    END AS ContributorStatus
FROM 
    FinalReport
WHERE 
    TotalPosts > 5
ORDER BY 
    UpVotesReceived DESC, AnswersGiven DESC;
