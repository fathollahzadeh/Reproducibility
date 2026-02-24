WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        P.OwnerUserId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVoteCount,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN PH.Id IS NOT NULL THEN 1 END) AS HistoryCount
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        P.Id, P.PostTypeId, P.OwnerUserId
),
UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT PS.PostId) AS TotalPosts,
        SUM(PS.UpVoteCount) AS TotalUpVotes,
        SUM(PS.DownVoteCount) AS TotalDownVotes,
        SUM(PS.CommentCount) AS TotalComments,
        SUM(PS.HistoryCount) AS TotalHistoryEntries
    FROM 
        Users U
    LEFT JOIN 
        PostStats PS ON U.Id = PS.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalUpVotes,
    TotalDownVotes,
    TotalComments,
    TotalHistoryEntries
FROM 
    UserPostStats
ORDER BY 
    TotalPosts DESC, TotalUpVotes DESC;