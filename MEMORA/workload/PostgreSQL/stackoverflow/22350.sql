
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.OwnerUserId,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS RankScore,
        ROW_NUMBER() OVER (ORDER BY P.CreationDate DESC) AS RowNum,
        COALESCE(NULLIF(P.Body, ''), 'No Content') AS BodyContent
    FROM 
        Posts P
    WHERE 
        P.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
        AND P.PostTypeId = 1 
),
UserVotes AS (
    SELECT 
        V.PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN V.VoteTypeId = 1 THEN 1 END) AS AcceptedVotes
    FROM 
        Votes V
    JOIN 
        RankedPosts RP ON V.PostId = RP.PostId
    GROUP BY 
        V.PostId
),
CloseReasons AS (
    SELECT 
        PH.PostId,
        STRING_AGG(CRT.Name, ', ') AS CloseReasons
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes CRT ON PH.Comment = CAST(CRT.Id AS TEXT)
    WHERE 
        PH.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        PH.PostId
)
SELECT 
    UP.Id AS UserId,
    UP.DisplayName,
    RP.PostId,
    RP.Title,
    RP.BodyContent,
    RP.CreationDate,
    RP.Score,
    COALESCE(UV.UpVotes, 0) AS TotalUpVotes,
    COALESCE(UV.DownVotes, 0) AS TotalDownVotes,
    COALESCE(CR.CloseReasons, 'No close reasons') AS CloseReasons,
    CASE 
        WHEN RP.RankScore = 1 THEN 'Top Question'
        WHEN RP.RankScore IS NULL THEN 'No Questions Available'
        ELSE 'Regular Question' 
    END AS QuestionCategory
FROM 
    RankedPosts RP
LEFT JOIN 
    Users UP ON RP.OwnerUserId = UP.Id
LEFT JOIN 
    UserVotes UV ON RP.PostId = UV.PostId
LEFT JOIN 
    CloseReasons CR ON RP.PostId = CR.PostId
WHERE 
    RP.RowNum <= 10 
ORDER BY 
    RP.Score DESC, UP.Reputation DESC;
