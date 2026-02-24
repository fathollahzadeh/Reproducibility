
WITH UserStats AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
RankedUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        QuestionCount, 
        AnswerCount, 
        UpVotes, 
        DownVotes,
        RANK() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        UserStats
),
ActiveUsers AS (
    SELECT 
        R.*,
        CASE 
            WHEN R.QuestionCount > R.AnswerCount THEN 'More Questions'
            WHEN R.AnswerCount > R.QuestionCount THEN 'More Answers'
            ELSE 'Equal' 
        END AS EngagementType
    FROM 
        RankedUsers R
)
SELECT 
    AU.DisplayName, 
    AU.Reputation, 
    AU.QuestionCount, 
    AU.AnswerCount, 
    AU.UpVotes, 
    AU.DownVotes, 
    AU.Rank, 
    AU.EngagementType,
    COUNT(PH.Id) AS PostHistoryCount,
    STRING_AGG(T.TagName, ',') AS TagsUsed
FROM 
    ActiveUsers AU
LEFT JOIN 
    PostHistory PH ON AU.UserId = PH.UserId
LEFT JOIN 
    Posts P ON AU.UserId = P.OwnerUserId
LEFT JOIN 
    Tags T ON T.ExcerptPostId = P.Id 
GROUP BY 
    AU.DisplayName, AU.Reputation, AU.QuestionCount, AU.AnswerCount, AU.UpVotes, AU.DownVotes, AU.Rank, AU.EngagementType
ORDER BY 
    AU.Rank;
