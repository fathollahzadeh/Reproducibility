
WITH RECURSIVE UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(P.Id) AS PostCount,
        SUM(V.BountyAmount) AS TotalBounty,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY COUNT(P.Id) DESC) AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        TotalBounty,
        UpVotes,
        DownVotes,
        UserRank 
    FROM 
        UserActivity
    WHERE 
        UserRank <= 10
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        COALESCE(NULLIF(P.AcceptedAnswerId, -1), 0) AS AcceptedAnswerId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COALESCE(MAX(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(MAX(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
        ROW_NUMBER() OVER (ORDER BY P.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount, P.AcceptedAnswerId
),
AggregatedData AS (
    SELECT 
        U.DisplayName,
        U.Reputation,
        SUM(P.ViewCount) AS TotalViews,
        COUNT(DISTINCT P.PostId) AS TotalPosts,
        AVG(P.CommentCount) AS AvgCommentsPerPost,
        SUM(P.TotalUpVotes) AS TotalUpVotes,
        SUM(P.TotalDownVotes) AS TotalDownVotes
    FROM 
        TopUsers U
    JOIN 
        PostStats P ON U.UserId = P.AcceptedAnswerId
    GROUP BY 
        U.DisplayName, U.Reputation
)
SELECT 
    A.DisplayName,
    A.Reputation,
    A.TotalViews,
    A.TotalPosts,
    A.AvgCommentsPerPost,
    (A.TotalUpVotes - A.TotalDownVotes) AS NetVotes
FROM 
    AggregatedData A
ORDER BY 
    A.TotalPosts DESC, A.TotalViews DESC;
