WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT CASE WHEN V.VoteTypeId IN (2, 3) THEN V.PostId END) AS TotalPostsVoted,
        COUNT(DISTINCT B.Id) AS TotalBadges
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostsWithHistory AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        PH.Comment AS CloseReason,
        PH.CreationDate AS HistoryDate,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY PH.CreationDate DESC) AS LatestHistory
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId 
        AND PH.PostHistoryTypeId IN (10, 11) 
    WHERE 
        P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 YEAR'
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        COALESCE(CAST(ROUND(AVG(CASE WHEN C.Text IS NOT NULL THEN C.Score END), 2) AS NUMERIC), 0) AS AvgCommentScore,
        STRING_AGG(DISTINCT Tags.TagName, ', ') AS TagList
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        LATERAL (SELECT unnest(string_to_array(P.Tags, ','::text)) AS TagName) Tags ON TRUE
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id, P.Title, P.ViewCount
)
SELECT 
    U.DisplayName,
    U.Reputation,
    COALESCE(PW.PostId, -1) AS RecentPostId,
    COALESCE(PW.Title, 'No Recent Post') AS RecentPostTitle,
    COALESCE(PW.CloseReason, 'N/A') AS RecentPostCloseReason,
    UPV.UpVotes,
    UPV.DownVotes,
    PS.ViewCount AS TotalViews,
    PS.AvgCommentScore,
    PS.TagList
FROM 
    UserVoteStats UPV
JOIN 
    Users U ON U.Id = UPV.UserId
LEFT JOIN 
    PostsWithHistory PW ON PW.LatestHistory = 1 AND PW.PostId = U.Id
LEFT JOIN 
    PostStatistics PS ON PS.PostId = PW.PostId
WHERE 
    U.Reputation IS NOT NULL 
    AND (U.Location IS NOT NULL OR U.AboutMe IS NOT NULL) 
ORDER BY 
    UPV.UpVotes DESC, 
    U.Reputation DESC
LIMIT 50;