WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END), 0) AS TotalVotes
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(P.ViewCount) AS TotalViews,
        MAX(P.LastActivityDate) AS LastActivity
    FROM Posts P
    GROUP BY P.OwnerUserId
),
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS TotalBadges,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM Badges B
    GROUP BY B.UserId
),
UserRanks AS (
    SELECT 
        U.Id AS UserId,
        RANK() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM Users U
),
CombinedData AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(US.TotalUpVotes, 0) AS TotalUpVotes,
        COALESCE(US.TotalDownVotes, 0) AS TotalDownVotes,
        COALESCE(PS.TotalPosts, 0) AS TotalPosts,
        COALESCE(PS.TotalQuestions, 0) AS TotalQuestions,
        COALESCE(PS.TotalAnswers, 0) AS TotalAnswers,
        COALESCE(PS.TotalViews, 0) AS TotalViews,
        COALESCE(UB.TotalBadges, 0) AS TotalBadges,
        COALESCE(UB.BadgeNames, 'None') AS BadgeNames,
        COALESCE(UR.UserRank, 1000) AS UserRank
    FROM Users U
    LEFT JOIN UserVoteStats US ON U.Id = US.UserId
    LEFT JOIN PostStats PS ON U.Id = PS.OwnerUserId
    LEFT JOIN UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN UserRanks UR ON U.Id = UR.UserId
)
SELECT 
    CD.UserId,
    CD.DisplayName,
    CD.TotalUpVotes,
    CD.TotalDownVotes,
    CD.TotalPosts,
    CD.TotalQuestions,
    CD.TotalAnswers,
    CD.TotalViews,
    CD.TotalBadges,
    CD.BadgeNames,
    CD.UserRank,
    CASE 
        WHEN CD.TotalUpVotes IS NULL OR CD.TotalDownVotes IS NULL THEN 'Vote data is incomplete'
        ELSE 
            CASE 
                WHEN CD.TotalUpVotes > CD.TotalDownVotes THEN 'Positive Engagement'
                WHEN CD.TotalDownVotes > CD.TotalUpVotes THEN 'Negative Engagement'
                ELSE 'Neutral Engagement'
            END
    END AS EngagementStatus
FROM CombinedData CD
WHERE 
    (CD.TotalQuestions > 0 OR CD.TotalAnswers > 0)
    AND (CD.TotalBadges > 0 OR CD.UserRank < 50)
ORDER BY CD.UserRank, CD.TotalPosts DESC;

