
WITH UserBadgeCount AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        COUNT(C.Id) AS CommentCount,
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 2) AS UpVoteCount,
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 3) AS DownVoteCount,
        MAX(P.CreationDate) AS LastActivityDate
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.OwnerUserId
),
UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        COALESCE(SUM(PS.CommentCount), 0) AS TotalComments,
        COALESCE(SUM(PS.UpVoteCount), 0) AS TotalUpVotes,
        COALESCE(SUM(PS.DownVoteCount), 0) AS TotalDownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        PostStatistics PS ON P.Id = PS.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
UserBadgeAndPostStats AS (
    SELECT 
        UBC.UserId,
        UBC.DisplayName,
        UBC.BadgeCount,
        UBC.BadgeNames,
        UPS.PostCount,
        UPS.TotalComments,
        UPS.TotalUpVotes,
        UPS.TotalDownVotes
    FROM 
        UserBadgeCount UBC
    JOIN 
        UserPostStats UPS ON UBC.UserId = UPS.UserId
)
SELECT 
    *,
    CASE 
        WHEN PostCount > 0 THEN ROUND((TotalUpVotes / PostCount::numeric) * 100, 2)
        ELSE 0
    END AS UpvoteRatio,
    CASE 
        WHEN TotalComments > 0 THEN ROUND((TotalUpVotes / TotalComments::numeric) * 100, 2)
        ELSE 0
    END AS UpvoteToCommentRatio
FROM 
    UserBadgeAndPostStats
ORDER BY 
    BadgeCount DESC, TotalUpVotes DESC;
