
WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounties,
        COALESCE(SUM(U.Views), 0) AS TotalViews,
        COALESCE(SUM(U.UpVotes), 0) AS TotalUpVotes,
        COALESCE(SUM(U.DownVotes), 0) AS TotalDownVotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        PT.Name AS PostType,
        COUNT(C.Id) AS TotalComments,
        COUNT(DISTINCT V.Id) AS TotalVotes,
        P.OwnerUserId -- Added this column to the GROUP BY clause
    FROM Posts P
    JOIN PostTypes PT ON P.PostTypeId = PT.Id
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id, P.Title, P.CreationDate, PT.Name, P.OwnerUserId
)
SELECT 
    U.DisplayName,
    U.TotalPosts,
    U.TotalComments,
    U.TotalBounties,
    U.TotalViews,
    U.TotalUpVotes,
    U.TotalDownVotes,
    P.PostId,
    P.Title AS PostTitle,
    P.CreationDate AS PostCreationDate,
    P.PostType,
    P.TotalComments AS PostTotalComments,
    P.TotalVotes AS PostTotalVotes
FROM UserStatistics U
JOIN PostStatistics P ON U.UserId = P.OwnerUserId
ORDER BY U.TotalPosts DESC, P.TotalVotes DESC;
