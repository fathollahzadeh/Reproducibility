WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.PostTypeId = 2 AND P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Rank
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
        TotalPosts, 
        Questions, 
        Answers, 
        AcceptedAnswers, 
        Upvotes, 
        Downvotes, 
        Rank
    FROM 
        UserStatistics
    WHERE 
        Rank <= 10
),
PostEngagement AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        C.UserId AS CommentUserId,
        COUNT(C.Id) AS CommentCount,
        MAX(C.CreationDate) AS LastCommentDate,
        CASE 
            WHEN PH.PostId IS NOT NULL THEN 'Closed' 
            ELSE 'Open' 
        END AS PostStatus
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, C.UserId, PH.PostId
)
SELECT 
    U.DisplayName AS TopUser,
    U.Reputation AS UserReputation,
    P.Title AS PostTitle,
    P.Score AS PostScore,
    P.ViewCount AS PostViews,
    P.CommentCount AS TotalComments,
    P.LastCommentDate,
    P.PostStatus
FROM 
    TopUsers U
JOIN 
    PostEngagement P ON P.CommentUserId = U.UserId
ORDER BY 
    U.Reputation DESC, P.Score DESC;
