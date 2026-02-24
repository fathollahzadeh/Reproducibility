WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotesReceived,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotesReceived,
        COUNT(DISTINCT P.Id) AS PostsCount,
        COUNT(DISTINCT C.Id) AS CommentsCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        U.Reputation >= 1000
    GROUP BY 
        U.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        UpVotesReceived,
        DownVotesReceived,
        PostsCount,
        CommentsCount,
        ROW_NUMBER() OVER (ORDER BY UpVotesReceived DESC, DownVotesReceived ASC) AS UserRank
    FROM 
        UserActivity
),
WorstClosedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        PH.CreationDate AS ClosingDate,
        PH.Comment AS CloseReason,
        DENSE_RANK() OVER (ORDER BY PH.CreationDate DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        PH.PostHistoryTypeId = 10  
        AND PH.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
PostTags AS (
    SELECT 
        P.Id AS PostId,
        STRING_AGG(TRIM(t.TagName), ', ') AS Tags
    FROM 
        Posts P
    JOIN 
        Tags t ON P.Tags LIKE '%' || t.TagName || '%'
    WHERE 
        P.PostTypeId = 1  
    GROUP BY 
        P.Id
)
SELECT 
    TU.DisplayName,
    TU.UpVotesReceived,
    TU.DownVotesReceived,
    TU.PostsCount,
    TU.CommentsCount,
    WCP.PostId,
    WCP.Title AS ClosedPostTitle,
    WCP.ClosingDate,
    WCP.CloseReason,
    PT.Tags
FROM 
    TopUsers TU
LEFT JOIN 
    WorstClosedPosts WCP ON TU.UserId = WCP.PostId
LEFT JOIN 
    PostTags PT ON WCP.PostId = PT.PostId
WHERE 
    TU.UserRank <= 10
ORDER BY 
    TU.UpVotesReceived DESC, 
    TU.DownVotesReceived ASC;