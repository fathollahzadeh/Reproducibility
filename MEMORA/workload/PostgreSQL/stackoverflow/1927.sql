WITH UserPopularity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.ViewCount IS NOT NULL THEN P.ViewCount ELSE 0 END) AS TotalViews,
        SUM(CASE WHEN P.Score IS NOT NULL THEN P.Score ELSE 0 END) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > 0
    GROUP BY 
        U.Id, U.DisplayName
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COALESCE(PV.TotalVotes, 0) AS VoteCount
    FROM 
        Posts P
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS TotalVotes
        FROM 
            Votes 
        GROUP BY 
            PostId
    ) PV ON P.Id = PV.PostId
),
PopularUsers AS (
    SELECT 
        UP.UserId,
        UP.DisplayName,
        UP.TotalPosts,
        UP.TotalViews,
        UP.TotalScore,
        ROW_NUMBER() OVER (ORDER BY UP.TotalScore DESC) AS Rank
    FROM 
        UserPopularity UP
    WHERE 
        UP.TotalPosts > 5
)

SELECT 
    PU.DisplayName AS PopularUser,
    P.Title AS PostTitle,
    P.CreationDate AS PostCreationDate,
    P.Score AS PostScore,
    P.VoteCount AS PostVoteCount
FROM 
    PopularUsers PU
JOIN 
    PostDetails P ON PU.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = P.PostId LIMIT 1)
WHERE 
    PU.Rank <= 10 
ORDER BY 
    PU.TotalScore DESC, P.VoteCount DESC;
