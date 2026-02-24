WITH RECURSIVE UserPostCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        ROW_NUMBER() OVER (ORDER BY COUNT(P.Id) DESC) AS Rank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName
),
RecentVotes AS (
    SELECT 
        V.UserId,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes
    FROM 
        Votes V
    WHERE 
        V.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month'
    GROUP BY 
        V.UserId
),
PostHistorySummary AS (
    SELECT 
        PH.UserId,
        COUNT(PH.Id) AS EditCount,
        SUM(CASE WHEN PH.PostHistoryTypeId IN (4, 5) THEN 1 ELSE 0 END) AS TitleOrBodyEdits,
        COUNT(DISTINCT PH.PostId) AS DistinctPostsEdited
    FROM 
        PostHistory PH
    GROUP BY 
        PH.UserId
)
SELECT 
    UPC.DisplayName,
    UPC.PostCount,
    UPC.QuestionCount,
    UPC.AnswerCount,
    RV.VoteCount,
    RV.DownVotes,
    RV.UpVotes,
    PHS.EditCount,
    PHS.TitleOrBodyEdits,
    PHS.DistinctPostsEdited
FROM 
    UserPostCounts UPC
LEFT JOIN 
    RecentVotes RV ON UPC.UserId = RV.UserId
LEFT JOIN 
    PostHistorySummary PHS ON UPC.UserId = PHS.UserId
WHERE 
    UPC.Rank <= 50
ORDER BY 
    UPC.PostCount DESC, 
    UPC.QuestionCount DESC
LIMIT 100;