
WITH PostTagCounts AS (
    SELECT 
        P.Id AS PostId, 
        COUNT(T.Id) AS TagCount, 
        STRING_AGG(T.TagName, ', ') AS TagsList
    FROM 
        Posts P
    JOIN 
        (SELECT Id, unnest(string_to_array(trim(both '<>' FROM Tags), '><')) AS TagName FROM Posts) T ON P.Id = T.Id
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS Comments,
        COALESCE(COUNT(DISTINCT P.Id), 0) AS QuestionCount
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1
    LEFT JOIN 
        Comments C ON C.UserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName
),
PostHistoryStats AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS EditCount,
        STRING_AGG(PHT.Name, ', ') AS EditTypes
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.PostId
)
SELECT 
    U.DisplayName AS UserName,
    P.Id AS PostId,
    P.Title AS PostTitle,
    PTag.TagCount,
    PTag.TagsList,
    UAct.UpVotes,
    UAct.DownVotes,
    UAct.Comments AS UserComments,
    UAct.QuestionCount AS TotalQuestions,
    PHSt.EditCount,
    PHSt.EditTypes
FROM 
    Users U
JOIN 
    UserActivity UAct ON U.Id = UAct.UserId
JOIN 
    Posts P ON P.OwnerUserId = U.Id AND P.PostTypeId = 1 
LEFT JOIN 
    PostTagCounts PTag ON P.Id = PTag.PostId
LEFT JOIN 
    PostHistoryStats PHSt ON P.Id = PHSt.PostId
WHERE 
    U.Reputation > 1000 
ORDER BY 
    U.Reputation DESC, 
    P.Id;
