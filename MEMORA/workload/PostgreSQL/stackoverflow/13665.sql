
WITH UserStats AS (
    SELECT 
        Users.Id AS UserId,
        Users.Reputation,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(Posts.ViewCount) AS TotalViews,
        SUM(Posts.Score) AS TotalScore
    FROM Users
    LEFT JOIN Posts ON Users.Id = Posts.OwnerUserId
    GROUP BY Users.Id, Users.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        PostCount,
        TotalViews,
        TotalScore,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC) AS Rank
    FROM UserStats
),
PostDetails AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        Posts.CreationDate,
        Posts.Score,
        Posts.ViewCount,
        Users.DisplayName AS OwnerDisplayName,
        PostTypes.Name AS PostTypeName,
        Posts.OwnerUserId
    FROM Posts
    JOIN Users ON Posts.OwnerUserId = Users.Id
    JOIN PostTypes ON Posts.PostTypeId = PostTypes.Id
)
SELECT 
    TopUsers.UserId,
    TopUsers.Reputation,
    TopUsers.PostCount,
    TopUsers.TotalViews,
    TopUsers.TotalScore,
    PostDetails.PostId,
    PostDetails.Title,
    PostDetails.CreationDate,
    PostDetails.Score,
    PostDetails.ViewCount,
    PostDetails.OwnerDisplayName,
    PostDetails.PostTypeName
FROM TopUsers
JOIN PostDetails ON TopUsers.UserId = PostDetails.OwnerUserId
WHERE TopUsers.Rank <= 10
ORDER BY TopUsers.Rank, PostDetails.Score DESC;
