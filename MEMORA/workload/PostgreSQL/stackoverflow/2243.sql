
WITH UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(VB.BountyAmount) AS TotalBounties,
        RANK() OVER (ORDER BY SUM(P.Score) DESC) AS ScoreRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes VB ON P.Id = VB.PostId AND VB.VoteTypeId = 8
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalBounties,
        ScoreRank
    FROM 
        UserEngagement
    WHERE 
        PostCount > 0
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COUNT(CI.Id) AS CommentCount,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS PostRank
    FROM 
        Posts P
    LEFT JOIN 
        Comments CI ON P.Id = CI.PostId
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 DAY'
    GROUP BY 
        P.Id, P.Title, P.CreationDate
)
SELECT 
    TU.DisplayName,
    TU.PostCount,
    TU.QuestionCount,
    TU.AnswerCount,
    COALESCE(SUM(PD.CommentCount), 0) AS TotalComments,
    TU.TotalBounties,
    CASE 
        WHEN TU.ScoreRank <= 10 THEN 'Top Contributor'
        ELSE 'Regular Contributor'
    END AS ContributorStatus
FROM 
    TopUsers TU
LEFT JOIN 
    PostDetails PD ON TU.UserId = PD.PostId
GROUP BY 
    TU.DisplayName, TU.PostCount, TU.QuestionCount, TU.AnswerCount, TU.TotalBounties, TU.ScoreRank
ORDER BY 
    TU.TotalBounties DESC, TU.PostCount DESC;
