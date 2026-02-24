WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON C.UserId = U.Id
    LEFT JOIN 
        Votes V ON V.UserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName
), 
PostHistorySummary AS (
    SELECT 
        PH.PostId,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (12, 13) THEN 1 END) AS DeleteCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (24) THEN 1 END) AS EditCount
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
), 
TaggedPosts AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%' 
    GROUP BY 
        T.TagName
), 
RankedUsers AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.TotalPosts,
        U.TotalComments,
        RANK() OVER (ORDER BY U.UpVotes DESC) AS VoteRank
    FROM 
        UserStatistics U
)

SELECT 
    U.DisplayName AS UserDisplayName,
    U.TotalPosts AS NumberOfPosts,
    U.TotalComments AS NumberOfComments,
    COALESCE(PH.CloseCount, 0) AS TotalCloseActions,
    COALESCE(PH.DeleteCount, 0) AS TotalDeleteActions,
    COALESCE(PH.EditCount, 0) AS TotalEditActions,
    T.TagName AS PopularTag,
    T.PostCount AS NumberOfPostsWithTag,
    R.VoteRank
FROM 
    RankedUsers R
JOIN 
    UserStatistics U ON U.UserId = R.UserId
LEFT JOIN 
    PostHistorySummary PH ON PH.PostId = (
        SELECT 
            P.Id
        FROM 
            Posts P
        WHERE 
            P.OwnerUserId = U.UserId
        ORDER BY 
            P.CreationDate DESC
        LIMIT 1
    )
LEFT JOIN 
    TaggedPosts T ON T.PostCount = (
        SELECT 
            MAX(PostCount)
        FROM 
            TaggedPosts
    )
WHERE 
    U.TotalPosts >= 5  /* considering users with at least 5 posts */
    AND U.UpVotes > U.DownVotes  /* users should have more upvotes than downvotes */
ORDER BY 
    R.VoteRank, U.DisplayName;

