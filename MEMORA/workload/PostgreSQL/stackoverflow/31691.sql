
WITH RecursiveUserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(V.Value, 0)) AS TotalVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        (SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS Value
         FROM 
            Votes 
         GROUP BY 
            PostId) V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate
),
UserScore AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        TotalVotes,
        DENSE_RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        RecursiveUserActivity
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY 
        T.TagName
    HAVING 
        COUNT(P.Id) > 5
),
RecentPostHistory AS (
    SELECT 
        PH.UserId, 
        PH.PostId,
        MAX(PH.CreationDate) AS LastEditDate
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        PH.UserId, PH.PostId
),
UserPostEditStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(RPH.PostId) AS EditCount,
        COUNT(DISTINCT RPH.PostId) AS UniquePostsEdited,
        RANK() OVER (ORDER BY COUNT(RPH.PostId) DESC) AS EditRank
    FROM 
        Users U
    JOIN 
        RecentPostHistory RPH ON U.Id = RPH.UserId
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    U.DisplayName AS UserName,
    U.PostCount AS TotalPosts,
    U.TotalVotes AS TotalVotes,
    PT.TagName AS PopularTag,
    UES.UniquePostsEdited AS TotalUniquePostsEdited,
    COALESCE(B.Name, 'No Badge') AS Badge
FROM 
    UserScore U
LEFT JOIN 
    PopularTags PT ON U.PostCount = (SELECT MAX(PostCount) FROM PopularTags)
LEFT JOIN 
    UserPostEditStatistics UES ON U.UserId = UES.UserId
LEFT JOIN 
    Badges B ON U.UserId = B.UserId AND B.Date = (SELECT MAX(Date) FROM Badges WHERE UserId = U.UserId)
WHERE 
    U.ReputationRank <= 10
ORDER BY 
    U.Reputation DESC;
