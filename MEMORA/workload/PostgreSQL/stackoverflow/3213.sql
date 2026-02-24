
WITH UserVoteSummary AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        COUNT(V.Id) AS TotalVotes, 
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes, 
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
ClosedPostDetails AS (
    SELECT 
        PH.UserId, 
        COUNT(PH.Id) AS ClosedPostsCount,
        SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS TotalClosed,
        SUM(CASE WHEN PH.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenedPosts
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        PH.UserId
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AvgViews,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
)
SELECT 
    US.DisplayName,
    US.Reputation,
    COALESCE(UD.ClosedPostsCount, 0) AS ClosedPostsCount,
    COALESCE(UD.TotalClosed, 0) AS TotalClosedPosts,
    COALESCE(UD.ReopenedPosts, 0) AS ReopenedPosts,
    PS.TotalPosts,
    PS.TotalScore,
    PS.AvgViews,
    ROW_NUMBER() OVER (ORDER BY US.TotalVotes DESC) AS UserRank
FROM 
    UserVoteSummary US
LEFT JOIN 
    ClosedPostDetails UD ON US.UserId = UD.UserId
LEFT JOIN 
    PostStatistics PS ON US.UserId = PS.OwnerUserId
WHERE 
    US.Reputation > (SELECT AVG(Reputation) FROM Users) 
    AND (PS.TotalPosts > 5 OR COALESCE(UD.ClosedPostsCount, 0) > 3)
ORDER BY 
    US.TotalVotes DESC, 
    PS.TotalScore DESC;
